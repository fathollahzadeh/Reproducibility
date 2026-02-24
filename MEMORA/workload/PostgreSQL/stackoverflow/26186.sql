
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.VoteTypeId IN (2, 3) 
    GROUP BY 
        v.PostId
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        COALESCE(rv.VoteCount, 0) AS VoteCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.Body,
    cd.Tags,
    cd.VoteCount,
    cd.CommentCount,
    CASE 
        WHEN cd.VoteCount > 10 THEN 'Hot Topic'
        WHEN cd.CommentCount > 5 THEN 'Engaging Question'
        ELSE 'Needs Improvement'
    END AS PostType
FROM 
    CombinedData cd
WHERE 
    cd.CommentCount > 0
ORDER BY 
    cd.VoteCount DESC, cd.CommentCount DESC
LIMIT 50;
