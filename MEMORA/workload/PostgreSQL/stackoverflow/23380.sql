WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) as TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadgeCounts AS (
    SELECT
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostActivity AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(ans.AnswerCount, 0) AS AnswerCount,
        COALESCE(ph.EditCount, 0) AS EditCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) ans ON p.Id = ans.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS EditCount
        FROM 
            PostHistory
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
)
SELECT 
    uvs.UserId,
    uvs.DisplayName,
    uvs.UpVotes,
    uvs.DownVotes,
    uvs.PostCount,
    uvs.TotalScore,
    ubc.GoldBadges,
    ubc.SilverBadges,
    ubc.BronzeBadges,
    pa.Title,
    pa.CreationDate,
    pa.CommentCount,
    pa.AnswerCount,
    CASE 
        WHEN pa.CommentCount > 10 THEN 'High Activity'
        WHEN pa.CommentCount BETWEEN 5 AND 10 THEN 'Medium Activity'
        ELSE 'Low Activity'
    END AS ActivityLevel
FROM 
    UserVoteStats uvs
LEFT JOIN 
    UserBadgeCounts ubc ON uvs.UserId = ubc.UserId
LEFT JOIN 
    PostActivity pa ON uvs.PostCount > 0
WHERE 
    uvs.TotalScore > (
        SELECT 
            AVG(TotalScore)
            FROM UserVoteStats
    )
ORDER BY 
    uvs.TotalScore DESC, 
    pa.CreationDate DESC
LIMIT 10;