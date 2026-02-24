
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
AggregatedUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS TotalUpvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS TotalDownvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostStatusHistory AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    up.TotalBadges,
    up.TotalScore,
    up.TotalViews,
    rp.PostId,
    rp.Title,
    rp.CreationDate AS QuestionDate,
    rp.Score AS QuestionScore,
    rp.ViewCount AS QuestionViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    COALESCE(rv.TotalUpvotes, 0) AS TotalUpvotes,
    COALESCE(rv.TotalDownvotes, 0) AS TotalDownvotes,
    ph.ClosedDate,
    ph.ReopenedDate
FROM 
    AggregatedUserStats up
LEFT JOIN 
    RankedPosts rp ON up.UserId = rp.OwnerUserId AND rp.RN <= 3
LEFT JOIN 
    RecentVotes rv ON rp.PostId = rv.PostId
LEFT JOIN 
    PostStatusHistory ph ON rp.PostId = ph.PostId
WHERE 
    up.Reputation > 1000 
ORDER BY 
    up.Reputation DESC, 
    rp.CreationDate DESC;
