
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.LastAccessDate,
        u.Views,
        CASE 
            WHEN u.Reputation IS NULL THEN 'Unknown'
            WHEN u.Reputation < 100 THEN 'Novice'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationClass
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
PostHistoryAggregate AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 13 THEN 1 END) AS UndeleteCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),
UsersWithTopPosts AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        RANK() OVER (PARTITION BY ur.UserId ORDER BY rp.Score DESC) AS TitleRank
    FROM 
        UserReputation ur
    JOIN 
        RankedPosts rp ON ur.UserId = rp.OwnerUserId
    WHERE 
        rp.PostRank <= 5 
)
SELECT 
    ur.DisplayName,
    ur.ReputationClass,
    utp.PostId,
    utp.Title,
    utp.CreationDate,
    COALESCE(pha.CloseCount, 0) AS TotalClosed,
    COALESCE(pha.ReopenCount, 0) AS TotalReopened,
    CASE 
        WHEN utp.CommentCount > 1 THEN 'Multiple Comments'
        ELSE 'Single Comment or No Comments'
    END AS CommentStatus
FROM 
    UserReputation ur
LEFT JOIN 
    UsersWithTopPosts utp ON ur.UserId = utp.UserId
LEFT JOIN 
    PostHistoryAggregate pha ON utp.PostId = pha.PostId
WHERE 
    utp.TitleRank = 1 
ORDER BY 
    ur.Reputation DESC,
    utp.CreationDate DESC;
