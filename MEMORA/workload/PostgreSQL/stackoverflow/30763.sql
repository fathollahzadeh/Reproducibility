
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
), 
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END), 0) AS ReopenVotes,
        COALESCE(SUM(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 ELSE 0 END), 0) AS DeleteVotes,
        COUNT(DISTINCT pp.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Posts pp ON u.Id = pp.OwnerUserId AND pp.PostTypeId = 1
    LEFT JOIN 
        PostHistory ph ON pp.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionCount,
        CloseVotes,
        ReopenVotes,
        DeleteVotes,
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC) AS Rank
    FROM 
        UserPostStats
    WHERE 
        QuestionCount > 0
)

SELECT 
    au.DisplayName,
    au.QuestionCount,
    au.CloseVotes,
    au.ReopenVotes,
    au.DeleteVotes,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount
FROM 
    ActiveUsers au
JOIN 
    RankedPosts rp ON au.UserId = rp.OwnerUserId
WHERE 
    au.Rank <= 10
ORDER BY 
    au.QuestionCount DESC, 
    rp.Score DESC
LIMIT 5 OFFSET 0;
