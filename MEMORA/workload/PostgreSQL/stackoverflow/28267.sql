
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) DESC) AS VoteRank
    FROM
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, '><')) AS tag(tag) ON true
    LEFT JOIN 
        Tags t ON t.TagName = tag.tag
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId
),

RecentActivePosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.CommentCount,
        rp.Tags,
        rp.VoteRank,
        ROW_NUMBER() OVER (ORDER BY p.LastActivityDate DESC) AS RecentRank
    FROM
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
    WHERE
        p.LastActivityDate >= CURRENT_DATE - INTERVAL '30 days'  
)

SELECT
    u.DisplayName,
    ra.PostId,
    ra.Title,
    ra.Body,
    ra.CreationDate,
    ra.CommentCount,
    ra.Tags,
    ra.VoteRank
FROM 
    RecentActivePosts ra
JOIN 
    Users u ON ra.OwnerUserId = u.Id
WHERE
    ra.RecentRank <= 10  
ORDER BY
    ra.CommentCount DESC, ra.VoteRank ASC;
