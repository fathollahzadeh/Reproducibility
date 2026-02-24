WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(p.Score) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 500 
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        pt.Name AS PostType,
        COALESCE(ph.RevisionCount, 0) AS RevisionCount,
        COALESCE(ac.AcceptedAnswerCount, 0) AS AcceptedAnswerCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS RevisionCount
        FROM 
            PostHistory
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AcceptedAnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) ac ON p.Id = ac.ParentId
    WHERE 
        p.CreationDate >= '2023-01-01' 
),
HighlyActiveUsers AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        ua.Reputation,
        COUNT(pd.PostId) AS ActivePosts
    FROM 
        UserActivity ua
    JOIN 
        PostDetails pd ON ua.UserId = pd.PostId
    GROUP BY 
        ua.UserId, ua.DisplayName, ua.Reputation
    HAVING 
        COUNT(pd.PostId) > 5 
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    pa.PostCount,
    pa.CommentCount,
    pa.TotalBounty,
    pa.AvgPostScore,
    pd.Title,
    pd.Tags,
    pd.PostType,
    pd.RevisionCount,
    pd.AcceptedAnswerCount
FROM 
    HighlyActiveUsers u
JOIN 
    UserActivity pa ON u.UserId = pa.UserId
JOIN 
    PostDetails pd ON pa.PostCount > 0
ORDER BY 
    u.Reputation DESC, pa.PostCount DESC;