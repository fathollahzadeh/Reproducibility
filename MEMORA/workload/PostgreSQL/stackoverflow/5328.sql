
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        MAX(u.CreationDate) AS AccountCreationDate,
        MAX(u.LastAccessDate) AS LastAccessDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostRanking AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        SUM(CASE WHEN ph.UserId IS NOT NULL THEN 1 ELSE 0 END) AS HistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title
),
TopPosts AS (
    SELECT 
        PostId, Title, VoteCount, Upvotes, Downvotes, HistoryCount,
        RANK() OVER (ORDER BY VoteCount DESC) AS Rank
    FROM 
        PostRanking
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    us.TotalComments,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    us.AccountCreationDate,
    us.LastAccessDate,
    tp.PostId,
    tp.Title AS TopPostTitle,
    tp.VoteCount AS TopPostVoteCount,
    tp.Upvotes AS TopPostUpvotes,
    tp.Downvotes AS TopPostDownvotes,
    tp.HistoryCount AS TopPostEditHistory,
    tp.Rank AS PostRank
FROM 
    UserStats us
LEFT JOIN 
    TopPosts tp ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId LIMIT 1)
WHERE 
    us.TotalPosts > 0
ORDER BY 
    us.TotalPosts DESC, tp.VoteCount DESC
FETCH FIRST 10 ROWS ONLY;
