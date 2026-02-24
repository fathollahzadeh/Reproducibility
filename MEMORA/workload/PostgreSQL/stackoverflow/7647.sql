WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.CreationDate ASC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
PostVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN vt.Name = 'AcceptedByOriginator' THEN 1 ELSE 0 END) AS AcceptedCount
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.OwnerDisplayName,
    pv.Upvotes,
    pv.Downvotes,
    pv.AcceptedCount
FROM 
    RankedPosts rp
JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
WHERE 
    rp.TagRank = 1 
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate ASC
LIMIT 50;