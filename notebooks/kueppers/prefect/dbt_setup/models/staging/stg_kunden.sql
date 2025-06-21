{{
  config(
    materialized='table'
  )
}}

-- Der Rest deines SQL-Codes bleibt genau gleich.
with source as (

    select * from {{ source('rohdaten', 'kunden') }}

),

renamed as (

    select
        "KundenID" as kunden_id,
        "Name" as kunden_name,
        "Stadt" as stadt,
        "RegistriertAm" as registriert_am

    from source

)

select * from renamed
