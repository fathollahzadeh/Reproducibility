WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Tags, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UniqueVoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1 AND

        
        EXISTS (
            SELECT 1
            FROM unnest(string_to_array(rp.Tags, '>')) AS tag
            WHERE tag IN ('sql', 'postgresql', 'database')
        )
)
SELECT 
    p.PostId,
    p.Title,
    p.OwnerDisplayName,
    p.CommentCount,
    p.UniqueVoteCount,
    (SELECT COUNT(*) FROM PostHistory ph WHERE ph.PostId = p.PostId) AS EditHistoryCount,
    (SELECT STRING_AGG(b.Name, ', ') 
        FROM Badges b 
        JOIN Users u ON b.UserId = u.Id 
        WHERE u.DisplayName = p.OwnerDisplayName) AS OwnerBadges
FROM 
    FilteredPosts p
ORDER BY 
    p.UniqueVoteCount DESC,
    p.CommentCount DESC
LIMIT 10;