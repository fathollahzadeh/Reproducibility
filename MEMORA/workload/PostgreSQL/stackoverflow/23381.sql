
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),
PostHistoryWithTags AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        p.Title,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(bp.Id) FILTER (WHERE bp.Id IS NOT NULL) AS BadgesCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        Tags t ON t.ExcerptPostId = p.Id
    LEFT JOIN 
        Badges bp ON bp.UserId = p.OwnerUserId
    WHERE 
        ph.CreationDate >= p.CreationDate
    GROUP BY 
        ph.PostId, ph.CreationDate, p.Title
),
PostsWithPerformance AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CommentCount,
        r.UpVotes,
        r.DownVotes,
        pht.Tags,
        CASE 
            WHEN r.Rank = 1 THEN 'Top Post'
            ELSE 'Regular Post' 
        END AS PerformanceCategory
    FROM 
        RankedPosts r
    LEFT JOIN 
        PostHistoryWithTags pht ON r.PostId = pht.PostId
)
SELECT 
    pwp.PostId,
    pwp.Title,
    COALESCE(pwp.CommentCount, 0) AS CommentCount,
    COALESCE(pwp.UpVotes, 0) AS UpVotes,
    COALESCE(pwp.DownVotes, 0) AS DownVotes,
    COALESCE(pwp.Tags, 'No Tags') AS Tags,
    pwp.PerformanceCategory,
    CASE 
        WHEN pwp.UpVotes - pwp.DownVotes > 0 THEN 'Positive Feedback'
        WHEN pwp.UpVotes - pwp.DownVotes < 0 THEN 'Negative Feedback'
        ELSE 'Neutral Feedback' 
    END AS FeedbackType,
    (SELECT COUNT(*) 
     FROM Votes v
     WHERE v.PostId = pwp.PostId AND v.VoteTypeId IN (1, 2, 5)
     ) AS EngagementScore
FROM 
    PostsWithPerformance pwp
WHERE 
    pwp.CommentCount > 0 OR pwp.UpVotes > 0
ORDER BY 
    FeedbackType DESC, EngagementScore DESC;
