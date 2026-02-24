
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),

ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.LastAccessDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month'
    GROUP BY 
        u.Id, u.DisplayName
),

PostHistoryData AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS Edits,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph 
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    au.DisplayName AS Author,
    au.PostsCount,
    au.UpVotesCount,
    COALESCE(phe.Edits, 0) AS EditCount,
    phe.FirstEditDate,
    phe.LastEditDate,
    CASE 
        WHEN rp.Score > 0 THEN 'Popular'
        WHEN rp.Score <= 0 AND rp.ViewCount > 100 THEN 'Controversial'
        ELSE 'Needs Attention'
    END AS PostStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    ActiveUsers au ON rp.Id = au.UserId
LEFT JOIN 
    PostHistoryData phe ON rp.Id = phe.PostId
WHERE 
    (rp.PostRank <= 5 OR (rp.ViewCount > 100 AND rp.AnswerCount = 0))
ORDER BY 
    rp.CreationDate DESC;
