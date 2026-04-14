interface FileSystemHandlePermissionDescriptor {
    mode?: 'read' | 'readwrite'
}

interface FileSystemHandle {
    kind: 'file' | 'directory'
    name: string
    isSameEntry(other: FileSystemHandle): Promise<boolean>
    queryPermission(descriptor?: FileSystemHandlePermissionDescriptor): Promise<PermissionState>
    requestPermission(descriptor?: FileSystemHandlePermissionDescriptor): Promise<PermissionState>
}

interface FileSystemFileHandle extends FileSystemHandle {
    kind: 'file'
    getFile(): Promise<File>
    createWritable(): Promise<FileSystemWritableFileStream>
}

interface FileSystemWritableFileStream extends WritableStream {
    write(data: BufferSource | Blob | string | { type: string; data?: BufferSource | Blob | string; position?: number; size?: number }): Promise<void>
    seek(position: number): Promise<void>
    truncate(size: number): Promise<void>
    close(): Promise<void>
}

interface OpenFilePickerOptions {
    multiple?: boolean
    types?: Array<{
        description?: string
        accept: Record<string, string[]>
    }>
    excludeAcceptAllOption?: boolean
    id?: string
    startIn?: FileSystemHandle | 'desktop' | 'documents' | 'downloads' | 'music' | 'pictures' | 'videos'
}

interface SaveFilePickerOptions {
    suggestedName?: string
    types?: Array<{
        description?: string
        accept: Record<string, string[]>
    }>
    excludeAcceptAllOption?: boolean
    id?: string
}

interface Window {
    showOpenFilePicker(options?: OpenFilePickerOptions): Promise<FileSystemFileHandle[]>
    showSaveFilePicker(options?: SaveFilePickerOptions): Promise<FileSystemFileHandle>
    showDirectoryPicker(options?: { id?: string; mode?: 'read' | 'readwrite'; startIn?: FileSystemHandle | 'desktop' | 'documents' | 'downloads' | 'music' | 'pictures' | 'videos' }): Promise<FileSystemDirectoryHandle>
}

interface FileSystemDirectoryHandle extends FileSystemHandle {
    kind: 'directory'
    getDirectoryHandle(name: string, options?: { create?: boolean }): Promise<FileSystemDirectoryHandle>
    getFileHandle(name: string, options?: { create?: boolean }): Promise<FileSystemFileHandle>
    removeEntry(name: string, options?: { recursive?: boolean }): Promise<void>
    entries(): AsyncIterableIterator<[string, FileSystemHandle]>
    values(): AsyncIterableIterator<FileSystemHandle>
    keys(): AsyncIterableIterator<string>
    [Symbol.asyncIterator](): AsyncIterableIterator<[string, FileSystemHandle]>
}
