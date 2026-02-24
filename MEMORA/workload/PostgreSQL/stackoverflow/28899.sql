
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.Title IS NOT NULL AND 
        CHAR_LENGTH(p.Body) > 100 AND 
        p.PostTypeId = 1 
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(rp.PostId) AS TotalQuestions,
        MAX(rp.CreationDate) AS LastQuestionDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 5 THEN 1 ELSE 0 END), 0) AS TotalFavorites
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = rp.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalQuestions,
        ups.LastQuestionDate,
        ups.TotalUpvotes,
        ups.TotalDownvotes,
        ups.TotalFavorites,
        ARRAY_AGG(DISTINCT rp.Tags) AS UniqueTags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgResponseTime
    FROM 
        UserPostStats ups
    JOIN 
        Posts p ON p.OwnerUserId = ups.UserId
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        RankedPosts rp ON rp.OwnerUserId = ups.UserId
    GROUP BY 
        ups.UserId, ups.DisplayName, ups.TotalQuestions, ups.LastQuestionDate, 
        ups.TotalUpvotes, ups.TotalDownvotes, ups.TotalFavorites
)
SELECT 
    pd.DisplayName,
    pd.TotalQuestions,
    pd.LastQuestionDate,
    pd.TotalUpvotes,
    pd.TotalDownvotes,
    pd.TotalFavorites,
    pd.UniqueTags,
    pd.CommentCount,
    pd.AvgResponseTime,
    CASE 
        WHEN pd.TotalQuestions > 10 THEN 'Active'
        WHEN pd.TotalQuestions BETWEEN 1 AND 10 THEN 'Moderate'
        ELSE 'Inactive'
    END AS UserActivityStatus
FROM 
    PostDetails pd
ORDER BY 
    pd.TotalQuestions DESC, pd.TotalUpvotes DESC;
