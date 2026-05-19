package persistence.service;

import com.citt.persistence.entity.Venta;
import com.citt.persistence.repository.VentaRepository;
import com.citt.persistence.services.VentaServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.time.LocalDate;

import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
public class VentaServiceTest {

    @Mock
    private VentaRepository ventaRepository;

    @InjectMocks
    private VentaServiceImpl ventaService;

    private Venta venta;

    @BeforeEach
    public void setUp(){
        venta = Venta.builder()
                .direccionCompra("Calle Falsa 123")
                .valorCompra(1000)
                .fechaCompra(LocalDate.of(2025,4,14))
                .despachoGenerado(false)
                .build();
    }

    @Test
    @DisplayName("Cuando se guarda una venta válida, entonces se persiste correctamente")
    @SuppressWarnings("null")
    public void whenSavingValidVenta_thenItIsPersistedCorrectly(){
        //Prepara la simulación
        if (venta != null) {
            when(ventaRepository.save(any(Venta.class))).thenReturn(venta);
        }

        //Llama al servicio
        Venta savedVenta = ventaService.saveVenta(venta);

        //Verifica el resultado
        if (venta != null) {
            verify(ventaRepository, times(1)).save(venta);
        }

        //Verifica que la venta guardada es la misma que la venta original
        assertNotNull(savedVenta);
        assertEquals(venta.getDireccionCompra(), savedVenta.getDireccionCompra());
        assertEquals(venta.getValorCompra(), savedVenta.getValorCompra());
        assertEquals(venta.getFechaCompra(), savedVenta.getFechaCompra());
        assertEquals(venta.getDespachoGenerado(), savedVenta.getDespachoGenerado());
    }

    @Test
    @DisplayName("Cuando se guarda una venta, entonces se asigna un ID")
    @SuppressWarnings("null")
    public void whenVentaIsSavedthenIdIsAssigned(){
        // Preparar
        Venta ventaToSave = Venta.builder()
                .direccionCompra("Calle Falsa 123")
                .valorCompra(1000)
                .fechaCompra(LocalDate.of(2025,4,14))
                .despachoGenerado(false)
                .build();

        Venta ventaWithId = Venta.builder()
                .idVenta(1L)
                .direccionCompra("Calle Falsa 123")
                .valorCompra(1000)
                .fechaCompra(LocalDate.of(2025,4,14))
                .despachoGenerado(false)
                .build();

        @SuppressWarnings("null")
        final Venta ventaWithIdNotNull = ventaWithId;
        if (ventaWithIdNotNull != null) {
            when(ventaRepository.save(any(Venta.class))).thenReturn(ventaWithIdNotNull);
        }

        // Ejecutar
        Venta result = ventaService.saveVenta(ventaToSave);

        // Verificar
        @SuppressWarnings("null")
        final Venta ventaToSaveNotNull = ventaToSave;
        if (ventaToSaveNotNull != null) {
            verify(ventaRepository).save(ventaToSaveNotNull);
        }
        assertNotNull(result);
        assertEquals(1L, result.getIdVenta());
        if (ventaToSaveNotNull != null) {
            assertEquals(ventaToSaveNotNull.getDireccionCompra(), result.getDireccionCompra());
        }
    }
}
