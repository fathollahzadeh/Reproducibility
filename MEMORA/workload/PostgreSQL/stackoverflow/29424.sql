WITH RankedPostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.ViewCount, p.Score, u.DisplayName
),

FilteredPosts AS (
    SELECT 
        rps.PostId,
        rps.Title,
        rps.Body,
        rps.ViewCount,
        rps.Score,
        rps.OwnerDisplayName,
        rps.CommentCount,
        rps.UpVotes,
        rps.DownVotes
    FROM 
        RankedPostStatistics rps
    WHERE 
        rps.PostRank <= 10 
)

SELECT 
    f.Title,
    f.ViewCount,
    f.Score,
    f.CommentCount,
    f.UpVotes,
    f.DownVotes,
    f.OwnerDisplayName,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
FROM 
    FilteredPosts f
LEFT JOIN 
    LATERAL (
        SELECT 
            UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS TagName
        FROM 
            Posts p
        WHERE 
            p.Id = f.PostId
    ) AS t ON TRUE
GROUP BY 
    f.PostId, f.Title, f.ViewCount, f.Score, f.CommentCount, f.UpVotes, f.DownVotes, f.OwnerDisplayName
ORDER BY 
    f.Score DESC, f.ViewCount DESC;