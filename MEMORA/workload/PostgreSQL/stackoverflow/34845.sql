WITH RecursiveTopPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        (SELECT COUNT(*) FROM Comments c WHERE c.UserId = u.Id) AS TotalComments,
        (SELECT SUM(pw.Score) FROM Posts pw WHERE pw.OwnerUserId = u.Id) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        ue.UserId,
        ue.DisplayName,
        ue.TotalQuestions,
        ue.TotalUpvotes,
        ue.TotalDownvotes,
        ue.TotalComments,
        ue.TotalScore,
        ROW_NUMBER() OVER (ORDER BY ue.TotalScore DESC) AS UserRank
    FROM 
        UserEngagement ue
    WHERE 
        ue.TotalScore IS NOT NULL
),
FilteredPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseVotes,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Tags
)
SELECT 
    r.Id AS PostId,
    r.Title AS TopPostTitle,
    r.Score AS TopPostScore,
    r.ViewCount AS TopPostViews,
    r.AnswerCount AS TopPostAnswers,
    tu.DisplayName AS TopUserDisplayName,
    tu.TotalQuestions AS TopUserQuestions,
    tu.TotalUpvotes AS TopUserUpvotes,
    tu.TotalDownvotes AS TopUserDownvotes,
    f.CommentCount AS RelatedPostComments,
    f.CloseVotes AS TotalCloseVotes,
    f.ReopenVotes AS TotalReopenVotes
FROM 
    RecursiveTopPosts r
JOIN 
    TopUsers tu ON r.Rank <= 10
LEFT JOIN 
    FilteredPosts f ON r.Id = f.Id
ORDER BY 
    r.Score DESC, tu.TotalScore DESC;