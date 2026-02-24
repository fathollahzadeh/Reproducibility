WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpvoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.CommentCount,
        rp.UpvoteCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Posts p2 WHERE p2.ParentId = rp.PostId AND p2.PostTypeId = 2) AS AnswerCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        Posts p ON p.Id = rp.PostId
    WHERE 
        rp.PostRank = 1 
        AND (rp.CommentCount > 5 OR rp.UpvoteCount > 10)
),
AggregatedData AS (
    SELECT 
        fp.OwnerDisplayName,
        SUM(fp.CommentCount) AS TotalComments,
        SUM(fp.UpvoteCount) AS TotalUpvotes,
        COUNT(fp.PostId) AS TotalPosts,
        AVG(fp.AnswerCount) AS AverageAnswers
    FROM 
        FilteredPosts fp
    GROUP BY 
        fp.OwnerDisplayName
),
ClosedPosts AS (
    SELECT 
        ph.UserId,
        ph.Comment,
        ph.CreationDate,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.UserId, ph.Comment, ph.CreationDate
)
SELECT 
    ad.OwnerDisplayName,
    ad.TotalComments,
    ad.TotalUpvotes,
    ad.TotalPosts,
    ad.AverageAnswers,
    COALESCE(cp.CloseCount, 0) AS TotalClosedPosts,
    CASE 
        WHEN ad.TotalPosts > 50 THEN 'Active User'
        ELSE 'New User'
    END AS UserType
FROM 
    AggregatedData ad
LEFT JOIN 
    ClosedPosts cp ON ad.OwnerDisplayName = (SELECT DisplayName FROM Users u WHERE u.Id = cp.UserId)
ORDER BY 
    ad.TotalUpvotes DESC, ad.TotalComments DESC;