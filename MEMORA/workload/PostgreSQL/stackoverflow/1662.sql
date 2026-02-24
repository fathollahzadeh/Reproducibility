WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS rn,
        COUNT(v.PostId) OVER (PARTITION BY p.Id) AS VoteCount,
        COALESCE(SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) OVER (PARTITION BY p.Id), 0) AS AnswerCount,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostHistoryCount AS (
    SELECT
        ph.PostId,
        COUNT(DISTINCT ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes - u.DownVotes) AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY SUM(u.Views) DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId, 
    rp.Title,
    u.DisplayName AS Owner,
    rp.Score,
    rp.CreationDate,
    phc.HistoryCount,
    rp.VoteCount,
    rp.AnswerCount,
    rp.CommentCount,
    au.NetVotes
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    PostHistoryCount phc ON rp.PostId = phc.PostId
LEFT JOIN 
    ActiveUsers au ON u.Id = au.UserId
WHERE 
    rp.rn = 1
  AND 
    (rp.AnswerCount > 0 OR au.NetVotes > 10)
ORDER BY 
    rp.Score DESC, 
    phc.HistoryCount ASC;