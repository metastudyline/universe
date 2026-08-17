/**
 * StudyLineBridgeClient - High-Performance Typed WebSocket Client with Heartbeat & Offline Fallback
 */

export type ConnectionState = "DISCONNECTED" | "CONNECTING" | "CONNECTED" | "RECONNECTING";

export interface BridgeMessage<T = any> {
    id: string;
    type: string;
    payload?: T;
    timestamp_ms: number;
}

export interface PathCalculatedPayload {
    target_node_id: string;
    path_nodes: string[];
    total_weight: number;
    calculation_time_us: number;
}

export interface GraphUpdatedPayload {
    blast_radius: {
        direct_changed: string[];
        affected_downstream: string[];
        total_impacted_count: number;
    };
    changed_files: string[];
}

export class StudyLineBridgeClient {
    private wsUrl: string;
    private socket: WebSocket | null = null;
    private state: ConnectionState = "DISCONNECTED";
    private reconnectAttempts = 0;
    private maxReconnectAttempts = 10;
    private heartbeatTimer: any = null;
    private heartbeatTimeout: any = null;
    private listeners: Map<string, Array<(payload: any) => void>> = new Map();
    private stateListeners: Array<(state: ConnectionState) => void> = [];

    constructor(wsUrl = "ws://127.0.0.1:3001/ws") {
        this.wsUrl = wsUrl;
    }

    public connect(): void {
        if (this.socket && (this.socket.readyState === WebSocket.OPEN || this.socket.readyState === WebSocket.CONNECTING)) {
            return;
        }

        this.setState(this.reconnectAttempts > 0 ? "RECONNECTING" : "CONNECTING");

        try {
            this.socket = new WebSocket(this.wsUrl);

            this.socket.onopen = () => {
                this.setState("CONNECTED");
                this.reconnectAttempts = 0;
                this.startHeartbeat();
                this.emit("connected", { url: this.wsUrl });
            };

            this.socket.onmessage = (event) => {
                try {
                    const msg: BridgeMessage = JSON.parse(event.data);
                    if (msg.type === "PONG") {
                        this.clearHeartbeatTimeout();
                    } else {
                        this.emit(msg.type, msg.payload);
                    }
                } catch (e) {
                    console.warn("[StudyLineBridge] Malformed message:", event.data);
                }
            };

            this.socket.onclose = () => {
                this.stopHeartbeat();
                this.setState("DISCONNECTED");
                this.scheduleReconnect();
            };

            this.socket.onerror = () => {
                this.socket?.close();
            };
        } catch (err) {
            this.setState("DISCONNECTED");
            this.scheduleReconnect();
        }
    }

    public calculatePath(targetNodeId: string, masteredIds: string[] = []): Promise<PathCalculatedPayload> {
        return new Promise((resolve, reject) => {
            if (!this.isConnected()) {
                // Fallback static calculation
                resolve({
                    target_node_id: targetNodeId,
                    path_nodes: [targetNodeId],
                    total_weight: 1,
                    calculation_time_us: 0
                });
                return;
            }

            const handler = (payload: PathCalculatedPayload) => {
                if (payload.target_node_id === targetNodeId) {
                    this.off("PATH_CALCULATED", handler);
                    resolve(payload);
                }
            };

            this.on("PATH_CALCULATED", handler);

            this.send({
                id: crypto.randomUUID(),
                type: "CALCULATE_PATH",
                payload: {
                    target_node_id: targetNodeId,
                    mastered_node_ids: masteredIds
                },
                timestamp_ms: Date.now()
            });

            // Timeout after 3s
            setTimeout(() => {
                this.off("PATH_CALCULATED", handler);
                reject(new Error("Path calculation timeout"));
            }, 3000);
        });
    }

    public send(msg: BridgeMessage): void {
        if (this.socket && this.socket.readyState === WebSocket.OPEN) {
            this.socket.send(JSON.stringify(msg));
        }
    }

    public isConnected(): boolean {
        return this.state === "CONNECTED";
    }

    public getState(): ConnectionState {
        return this.state;
    }

    public on(eventType: string, callback: (payload: any) => void): void {
        if (!this.listeners.has(eventType)) {
            this.listeners.set(eventType, []);
        }
        this.listeners.get(eventType)!.push(callback);
    }

    public off(eventType: string, callback: (payload: any) => void): void {
        const list = this.listeners.get(eventType);
        if (list) {
            this.listeners.set(eventType, list.filter(cb => cb !== callback));
        }
    }

    public onStateChange(callback: (state: ConnectionState) => void): void {
        this.stateListeners.push(callback);
        callback(this.state);
    }

    private emit(eventType: string, payload: any): void {
        const list = this.listeners.get(eventType);
        if (list) {
            list.forEach(cb => cb(payload));
        }
    }

    private setState(newState: ConnectionState): void {
        if (this.state !== newState) {
            this.state = newState;
            this.stateListeners.forEach(cb => cb(this.state));
        }
    }

    private scheduleReconnect(): void {
        if (this.reconnectAttempts >= this.maxReconnectAttempts) {
            return;
        }

        this.reconnectAttempts++;
        const baseDelay = Math.min(10000, 1000 * Math.pow(1.5, this.reconnectAttempts));
        const jitter = baseDelay * (Math.random() * 0.4 - 0.2); // +/- 20% jitter
        const delay = Math.round(baseDelay + jitter);

        setTimeout(() => {
            if (this.state === "DISCONNECTED" || this.state === "RECONNECTING") {
                this.connect();
            }
        }, delay);
    }

    private startHeartbeat(): void {
        this.stopHeartbeat();
        this.heartbeatTimer = setInterval(() => {
            if (this.isConnected()) {
                this.send({
                    id: crypto.randomUUID(),
                    type: "PING",
                    timestamp_ms: Date.now()
                });

                this.heartbeatTimeout = setTimeout(() => {
                    console.warn("[StudyLineBridge] Heartbeat timeout, closing dead socket");
                    this.socket?.close();
                }, 5000);
            }
        }, 15000);
    }

    private clearHeartbeatTimeout(): void {
        if (this.heartbeatTimeout) {
            clearTimeout(this.heartbeatTimeout);
            this.heartbeatTimeout = null;
        }
    }

    private stopHeartbeat(): void {
        if (this.heartbeatTimer) {
            clearInterval(this.heartbeatTimer);
            this.heartbeatTimer = null;
        }
        this.clearHeartbeatTimeout();
    }
}
