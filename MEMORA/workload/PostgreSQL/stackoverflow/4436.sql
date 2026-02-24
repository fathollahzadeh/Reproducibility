WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
MostCommentedPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        AcceptedAnswerId,
        CommentCount,
        UpVoteCount,
        DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        CommentCount > 10
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(SUM(CASE WHEN p.Score > 0 THEN p.Score END), 0) AS PositiveScores,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    ps.Title,
    ps.CreationDate,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ups.TotalViews,
    ups.PositiveScores,
    ups.TotalPosts,
    ups.BadgeCount
FROM 
    MostCommentedPosts ps
JOIN 
    Users u ON ps.AcceptedAnswerId = u.Id
JOIN 
    UserPostStats ups ON u.Id = ups.UserId
WHERE 
    ups.TotalViews > 1000
ORDER BY 
    ps.CommentCount DESC,
    ups.TotalViews DESC
LIMIT 10;