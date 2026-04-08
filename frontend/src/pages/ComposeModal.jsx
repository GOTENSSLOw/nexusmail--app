export const ComposeModal = ({ cerrarModal }) => {
    return (
        <div className="modal-overlay">
            <div className="modal-content">
                <div className="modal-header">
                    <h3>New Message</h3>
                    {/* Fíjate cómo conectamos el botón con la prop cerrarModal */}
                    <button className="btn-close" onClick={cerrarModal}>X</button>
                </div>
                
                <div className="modal-body">
                    <input type="text" placeholder="To" className="modal-input" />
                    <input type="text" placeholder="Subject" className="modal-input" />
                    <textarea placeholder="Write your message..." className="modal-textarea"></textarea>
                </div>
                
                <div className="modal-footer">
                    <button className="btn-send">Send</button>
                </div>
            </div>
        </div>
    );
};