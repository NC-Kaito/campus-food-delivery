    package com.it22mjudelivery.springboot_api.v1.entities;

    import com.fasterxml.jackson.annotation.JsonIgnore;
    import jakarta.persistence.*;
    import lombok.AllArgsConstructor;
    import lombok.Builder;
    import lombok.EqualsAndHashCode;
    import lombok.Getter;
    import lombok.NoArgsConstructor;
    import lombok.Setter;

    import java.util.List;
    import java.util.Set;

    @Entity
    @Table(name = "Menuoptiongroup")
    @Getter
    @Setter
    @AllArgsConstructor
    @NoArgsConstructor
    @Builder
    @EqualsAndHashCode(onlyExplicitlyIncluded = true) // ← เปลี่ยนจาก @Data เช่นกัน
    public class Optiongroup {

        @Id
        @EqualsAndHashCode.Include // ← ใช้แค่ id ในการเทียบ equals/hashCode
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        private int optiongroupid;

        @Column(length = 50, nullable = false)
        private String optiongroupname;

        @Column(nullable = false)
        private boolean is_required;

        @Column(nullable = false)
        @com.fasterxml.jackson.annotation.JsonProperty("is_multiple_choice")
        private boolean is_multiple_choice;

        @ManyToOne(fetch = FetchType.LAZY)
        @JoinColumn(name = "menuid", nullable = false)
        private  Menu memuid;
    }