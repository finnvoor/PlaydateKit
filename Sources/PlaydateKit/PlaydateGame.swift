public import CPlaydate

public protocol PlaydateGame {
    init()
    
    func eventHandler(_ event: PDSystemEvent)
    func update()
}
