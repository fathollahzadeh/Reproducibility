
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount
),
PostDiversity AS (
    SELECT
        rp.PostId,
        COUNT(DISTINCT tg.TagName) AS UniqueTagsCount
    FROM
        RankedPosts rp
    CROSS JOIN
        LATERAL (SELECT TRIM(both '<>' FROM unnest(string_to_array(rp.Tags, ','))) AS Tag) AS tag
    INNER JOIN
        Tags tg ON tg.TagName = tag.Tag
    GROUP BY
        rp.PostId
),
ResultSet AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        pd.UniqueTagsCount,
        DENSE_RANK() OVER (ORDER BY rp.Score DESC) AS ScoreRank
    FROM
        RankedPosts rp
    JOIN
        PostDiversity pd ON rp.PostId = pd.PostId
    WHERE
        rp.rn = 1
)

SELECT
    rs.PostId,
    rs.Title,
    rs.ViewCount,
    rs.Score,
    rs.AnswerCount,
    rs.CommentCount,
    rs.UniqueTagsCount,
    rs.ScoreRank,
    CASE 
        WHEN rs.UniqueTagsCount >= 5 THEN 'Highly Diverse'
        WHEN rs.UniqueTagsCount BETWEEN 3 AND 4 THEN 'Moderately Diverse'
        ELSE 'Low Diversity'
    END AS TagDiversity
FROM
    ResultSet rs
WHERE
    rs.ScoreRank <= 100
ORDER BY
    rs.Score DESC, rs.ViewCount DESC;
