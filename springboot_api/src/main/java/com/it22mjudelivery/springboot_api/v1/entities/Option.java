    package com.it22mjudelivery.springboot_api.v1.entities;

    import com.fasterxml.jackson.annotation.JsonIgnore;
    import jakarta.persistence.*;
    import lombok.*;

    import java.util.HashSet;
    import java.util.Set;

    @Entity
    @Table(name="Menuaddnodetail")
    @Getter
    @Setter
    @AllArgsConstructor
    @NoArgsConstructor
    @Builder
    @ToString(exclude = {"orderdetailaddons", "menuaddongroup", "addonmenu"})
    public class Option {
        @Id
        @GeneratedValue(strategy = GenerationType.IDENTITY)
        private int optionid;

        @Column(nullable = false)
        private double optionprice;

        @JsonIgnore
        @OneToMany(mappedBy = "menuoptiondetail", fetch = FetchType.LAZY)
        @Builder.Default
        private Set<Orderdetailoption> orderdetailoptions = new HashSet<>();

        @JsonIgnore
        @ManyToOne(fetch = FetchType.LAZY)
        @JoinColumn(name = "optiongroupid", nullable = true)
        private Optiongroup optiongroup;

//        @ManyToOne(fetch = FetchType.LAZY)
//        @JoinColumn(name = "addonid", nullable = false)
//        private Addonmenu addonmenu;

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (!(o instanceof Option)) return false;
            Option that = (Option) o;
            return optionid == that.optionid;
        }

        @Override
        public int hashCode() {
            return Integer.hashCode(optionid);
        }
    }