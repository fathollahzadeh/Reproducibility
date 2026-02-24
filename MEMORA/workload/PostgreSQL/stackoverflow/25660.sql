WITH RankedPosts AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        P.CreationDate,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS RN
    FROM
        Posts P
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    WHERE
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY
        P.Id
),
RankedVotes AS (
    SELECT
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM
        Votes V
    WHERE
        V.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY
        V.PostId
),
PopularTags AS (
    SELECT
        TRIM(UNNEST(string_to_array(P.Tags, '><'))) AS Tag,
        COUNT(*) AS TagCount
    FROM
        Posts P
    WHERE
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY
        Tag
    ORDER BY
        TagCount DESC
    LIMIT 10
)
SELECT
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.Tags,
    RP.CreationDate,
    RP.Score,
    RV.UpVotes,
    RV.DownVotes,
    RV.TotalVotes,
    PT.Tag AS PopularTag,
    PT.TagCount
FROM
    RankedPosts RP
LEFT JOIN
    RankedVotes RV ON RP.PostId = RV.PostId
CROSS JOIN
    PopularTags PT
WHERE
    RP.RN = 1  
ORDER BY
    RP.Score DESC,
    RV.TotalVotes DESC;