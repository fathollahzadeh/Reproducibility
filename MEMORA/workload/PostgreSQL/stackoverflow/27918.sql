WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId IN (10, 11) THEN 1 ELSE 0 END) AS TotalClosures,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetail AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ARRAY_TO_STRING(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '>'), ', ') AS ExtractedTags,
        COALESCE(phh.Comment, 'No closure reason') AS ClosureReason
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory phh ON p.Id = phh.PostId AND phh.PostHistoryTypeId = 10
    WHERE 
        p.PostTypeId = 1
),
RankedPosts AS (
    SELECT 
        pd.*,
        ROW_NUMBER() OVER (ORDER BY pd.ViewCount DESC) AS Rank
    FROM 
        PostDetail pd
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalClosures,
    us.TotalUpvotes,
    us.TotalDownvotes,
    rp.Title,
    rp.ViewCount,
    rp.CreationDate,
    rp.ExtractedTags,
    rp.ClosureReason,
    rp.Rank
FROM 
    UserStats us
JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
WHERE 
    us.TotalQuestions > 0
ORDER BY 
    us.TotalUpvotes DESC,
    rp.Rank;
