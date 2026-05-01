from app.core.uow import InMemoryUnitOfWork, AbstractUnitOfWork

# Şimdilik global bir in-memory uow nesnesi oluşturuyoruz
_uow = InMemoryUnitOfWork()

def get_uow() -> AbstractUnitOfWork:
    """
    FastAPI dependency injection için UoW sağlayıcısı.
    İleride veritabanı geldiğinde burası SqlAlchemyUnitOfWork döndürecek şekilde güncellenir.
    """
    return _uow
