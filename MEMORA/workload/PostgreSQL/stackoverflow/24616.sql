WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.PostTypeId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.AcceptedAnswerId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankPerUser
    FROM 
        Posts p
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        (SELECT COUNT(*) FROM Votes v WHERE v.UserId = u.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.UserId = u.Id AND v.VoteTypeId = 3) AS DownVotes,
        (SELECT SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) FROM Posts p WHERE p.OwnerUserId = u.Id) AS QuestionCount,
        (SELECT SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) FROM Posts p WHERE p.OwnerUserId = u.Id) AS AnswerCount,
        u.Reputation
    FROM 
        Users u
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (24, 25) THEN 1 END) AS EditCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    us.Reputation,
    us.UpVotes,
    us.DownVotes,
    us.QuestionCount,
    us.AnswerCount,
    COALESCE(phs.CloseCount, 0) AS CloseCount,
    COALESCE(phs.ReopenCount, 0) AS ReopenCount,
    COALESCE(phs.EditCount, 0) AS EditCount
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
JOIN 
    UserStats us ON us.UserId = u.Id
LEFT JOIN 
    PostHistoryStats phs ON phs.PostId = rp.PostId
WHERE 
    (rp.RankPerUser = 1 OR us.Reputation > 1000)
    AND (rp.PostTypeId IN (1, 2) OR us.QuestionCount > 3)
ORDER BY 
    us.Reputation DESC,
    rp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;