package com.antnexo.flutter

import kotlin.test.Test
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class OpeningsTest {
    @Test
    fun aCancelledOpeningStaysCancelledWhicheverArrivesFirst() {
        val o = Openings()
        assertFalse(o.isCancelled(0))
        o.cancel(0) // close() for opening 0 received before its show
        assertTrue(o.isCancelled(0))
        assertFalse(o.isCancelled(1))
        o.cancel(3)
        o.cancel(1) // late, smaller: keeps 3
        assertTrue(o.isCancelled(3))
        assertFalse(o.isCancelled(4))
    }

    @Test
    fun aNewDartIsolateStartsOver() {
        val o = Openings()
        o.cancel(5)
        o.reset() // hot restart: Dart counts from 0 again
        assertFalse(o.isCancelled(0))
    }
}
