WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 month' 
    GROUP BY 
        p.Id
    HAVING 
        p.Score > 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId, 
        ph.UserId, 
        ph.CreationDate,
        ph.Comment,
        p.Title AS PostTitle,
        p.ViewCount,
        PHT.Name AS PostHistoryType
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE 
        ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '6 months'
)
SELECT 
    ur.DisplayName,
    ur.Reputation,
    pp.PostId,
    pp.Title AS PopularPostTitle,
    pp.Score AS PopularPostScore,
    pp.ViewCount AS PopularPostViews,
    phd.CreationDate AS HistoryChangeDate,
    phd.PostHistoryType,
    COALESCE(phd.Comment, 'No Comment') AS ChangeComment
FROM 
    UserReputation ur
JOIN 
    PopularPosts pp ON ur.UserId IN (
        SELECT 
            DISTINCT OwnerUserId 
        FROM 
            Posts 
        WHERE 
            Id IN (SELECT DISTINCT PostId FROM PostLinks)
    )
LEFT JOIN 
    PostHistoryDetails phd ON pp.PostId = phd.PostId
WHERE 
    ur.ReputationRank <= 50
ORDER BY 
    ur.Reputation DESC, 
    pp.ViewCount DESC;