WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.PostTypeId,
        p.Title,
        p.AcceptedAnswerId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.AcceptedAnswerId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
UserVoteSummary AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes,
        COUNT(DISTINCT v.PostId) AS UniquePostsVoted
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COALESCE(bs.TotalBadges, 0) AS TotalBadges,
        CASE
            WHEN u.Reputation >= 1000 THEN 'Expert'
            WHEN u.Reputation >= 100 THEN 'Intermediate'
            ELSE 'Novice'
        END AS UserLevel
    FROM 
        Users u
    LEFT JOIN (
        SELECT 
            UserId, COUNT(*) AS TotalBadges
        FROM 
            Badges
        GROUP BY 
            UserId
    ) bs ON u.Id = bs.UserId
    WHERE 
        u.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId AS EditorUserId,
        ph.CreationDate,
        p.Title,
        ph.Comment,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
),
TopPostEditors AS (
    SELECT 
        ph.EditorUserId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistoryDetails ph
    GROUP BY 
        ph.EditorUserId
)

SELECT 
    pu.UserId,
    pu.DisplayName,
    pu.Reputation,
    pu.UserLevel,
    pu.TotalBadges,
    us.TotalVotes,
    us.UniquePostsVoted,
    COALESCE(te.EditCount, 0) AS TotalEdits,
    te.LastEditDate,
    COUNT(DISTINCT rp.Id) AS QuestionsAnswered,
    COUNT(DISTINCT ph.PostId) AS EditsCount
FROM 
    TopUsers pu
LEFT JOIN 
    UserVoteSummary us ON pu.UserId = us.UserId
LEFT JOIN 
    TopPostEditors te ON te.EditorUserId = pu.UserId
LEFT JOIN 
    RecursivePosts rp ON pu.UserId = rp.AcceptedAnswerId
LEFT JOIN 
    PostHistoryDetails ph ON pu.UserId = ph.EditorUserId
WHERE 
    pu.Reputation > 0
GROUP BY 
    pu.UserId, pu.DisplayName, pu.Reputation, pu.UserLevel, 
    pu.TotalBadges, us.TotalVotes, us.UniquePostsVoted, 
    te.EditCount, te.LastEditDate
ORDER BY 
    pu.Reputation DESC, TotalVotes DESC
LIMIT 50;