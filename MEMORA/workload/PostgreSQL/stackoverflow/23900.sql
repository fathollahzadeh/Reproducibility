WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS UserRank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostEngagement AS (
    SELECT
        p.Id,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
CombinedData AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        pe.CommentCount,
        pe.UpVoteCount,
        pe.DownVoteCount,
        rp.UserRank,
        CASE
            WHEN rp.UserRank = 1 THEN 'Top Post'
            WHEN rp.UserRank IS NULL THEN 'No Posts'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM RankedPosts rp
    LEFT JOIN PostEngagement pe ON rp.PostId = pe.Id
)
SELECT
    cd.PostId,
    cd.Title,
    cd.ViewCount,
    cd.CommentCount,
    cd.UpVoteCount,
    cd.DownVoteCount,
    cd.PostCategory,
    CASE 
        WHEN cd.UpVoteCount > cd.DownVoteCount THEN 'Positive Engagement'
        WHEN cd.UpVoteCount < cd.DownVoteCount THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementStatus,
    (SELECT STRING_AGG(t.TagName, ', ') FROM Tags t INNER JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%' WHERE p.Id = cd.PostId) AS RelatedTags,
    COALESCE(
        (SELECT COUNT(*) FROM Badges b WHERE b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cd.PostId)), 
        0) AS UserBadgeCount
FROM CombinedData cd
WHERE cd.ViewCount > 10
ORDER BY cd.UserRank, cd.ViewCount DESC;