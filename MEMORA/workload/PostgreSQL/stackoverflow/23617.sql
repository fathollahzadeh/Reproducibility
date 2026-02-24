WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankScore,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RankRecent,
        COALESCE(NULLIF(p.Body, ''), 'No Content') AS BodyContent
    FROM 
        Posts p
        JOIN PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        lp.RelatedPostId,
        lt.Name AS LinkTypeName
    FROM 
        RankedPosts rp
        LEFT JOIN PostLinks lp ON rp.PostId = lp.PostId
        LEFT JOIN LinkTypes lt ON lp.LinkTypeId = lt.Id
    WHERE 
        rp.RankScore <= 3 OR rp.RankRecent <= 10
),
UserVoteCounts AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM 
        Votes v
        JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
FinalReport AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.ViewCount,
        uvc.UpVotes,
        uvc.DownVotes,
        CASE 
            WHEN fp.LinkTypeName IS NOT NULL THEN CONCAT('Linked to Post ID: ', fp.RelatedPostId, ' as ', fp.LinkTypeName) 
            ELSE 'No Links'
        END AS LinkInfo,
        CASE 
            WHEN uvc.UpVotes > 0 AND uvc.DownVotes = 0 THEN 'Highly Favorable'
            WHEN uvc.DownVotes > 0 AND uvc.UpVotes = 0 THEN 'Unfavorably Received'
            ELSE 'Mixed Feedback'
        END AS FeedbackCategory
    FROM 
        FilteredPosts fp
        LEFT JOIN UserVoteCounts uvc ON fp.PostId = uvc.PostId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.CreationDate,
    fr.Score,
    fr.ViewCount,
    fr.UpVotes,
    fr.DownVotes,
    fr.LinkInfo,
    fr.FeedbackCategory,
    CASE 
        WHEN COALESCE(fr.Score, 0) > 0 THEN 'Popular Post'
        ELSE 'Needs Attention' 
    END AS PostStatus,
    COALESCE(
        STRING_AGG(b.Name, ', ') FILTER (WHERE b.Class = 1), 
        'No Gold Badges'
    ) AS GoldBadges
FROM 
    FinalReport fr
    LEFT JOIN Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = fr.PostId)
GROUP BY 
    fr.PostId, fr.Title, fr.CreationDate, fr.Score, fr.ViewCount, fr.UpVotes, fr.DownVotes, fr.LinkInfo, fr.FeedbackCategory
HAVING 
    SUM(fr.Score) IS DISTINCT FROM NULL
ORDER BY 
    fr.Score DESC, fr.CreationDate DESC
LIMIT 100;