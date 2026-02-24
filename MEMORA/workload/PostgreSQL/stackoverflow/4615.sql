WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(p.ViewCount) AS AvgViews,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) DESC) AS PostRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        PositivePosts, 
        NegativePosts, 
        AvgViews
    FROM 
        UserStats
    WHERE 
        PostRank <= 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(c.CommentCount, 0) AS Comments,
        COALESCE(vote.VoteCount, 0) AS UpVotes,
        COALESCE(closed.ClosedPostCount, 0) AS ClosedCount
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
            PostId, 
            COUNT(*) AS VoteCount
        FROM 
            Votes
        WHERE 
            VoteTypeId = 2
        GROUP BY 
            PostId
    ) vote ON p.Id = vote.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS ClosedPostCount
        FROM 
            PostHistory
        WHERE 
            PostHistoryTypeId = 10
        GROUP BY 
            PostId
    ) closed ON p.Id = closed.PostId
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    pd.Title,
    pd.CreationDate,
    pd.Comments,
    pd.UpVotes,
    pd.ClosedCount,
    CASE 
        WHEN pd.ClosedCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    TopUsers tu
JOIN 
    PostDetails pd ON tu.UserId = pd.PostId
ORDER BY 
    tu.Reputation DESC, 
    pd.UpVotes DESC;
