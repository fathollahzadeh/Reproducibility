WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        ur.UserId,
        ur.Reputation,
        ur.QuestionCount,
        ur.PositiveScoreCount,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS ReputationRank
    FROM 
        UserReputation ur
    WHERE 
        ur.QuestionCount > 10 AND ur.Reputation > 100
), 
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
),
PostStatistics AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        COALESCE(recentedit.UserId, -1) AS LastEditUserId,
        COALESCE(recentedit.Comment, '') AS LastEditComment,
        COALESCE(topUser.ReputationRank, 0) AS TopUserRepRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentEdits recentedit ON rp.PostID = recentedit.PostId AND recentedit.EditRank = 1
    LEFT JOIN 
        TopUsers topUser ON rp.OwnerUserId = topUser.UserId
)

SELECT 
    ps.PostID,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.LastEditUserId,
    ps.LastEditComment,
    ps.TopUserRepRank,
    CASE 
        WHEN ps.Score >= 100 THEN 'High scoring'
        WHEN ps.Score BETWEEN 50 AND 99 THEN 'Medium scoring'
        ELSE 'Low scoring'
    END AS ScoreCategory,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = ps.PostID) AS CommentCount
FROM 
    PostStatistics ps
WHERE 
    ps.TopUserRepRank > 0
ORDER BY 
    ps.Score DESC, ps.CreationDate DESC
LIMIT 50;