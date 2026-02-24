
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
          AND p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags
),

PopularTags AS (
    SELECT 
        UNNEST(string_to_array(p.Tags, '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        Tag
    ORDER BY 
        COUNT(*) DESC
    LIMIT 5 
),

TopPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    JOIN 
        PopularTags pt ON rp.Tags LIKE '%' || pt.Tag || '%'
    WHERE 
        rp.ScoreRank <= 10 
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.Tags,
    rp.UpVotes,
    rp.DownVotes,
    (SELECT COUNT(*) FROM PostLinks pl WHERE pl.PostId = rp.PostId) AS RelatedLinksCount,
    (SELECT STRING_AGG(b.Name, ', ') 
     FROM Badges b 
     JOIN Users u ON b.UserId = u.Id 
     WHERE u.Id IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = rp.PostId)) AS OwnerBadges
FROM 
    TopPosts rp
ORDER BY 
    rp.Score DESC,
    rp.ViewCount DESC;
