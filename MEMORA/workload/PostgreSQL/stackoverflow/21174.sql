
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        COALESCE(cnt.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) cnt ON p.Id = cnt.PostId
),
UserEngagement AS (
    SELECT
        u.Id AS UserID,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT v.PostId) AS TotalVotes,
        AVG(COALESCE(v.BountyAmount, 0)) AS AverageBounty
    FROM 
        Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentActivity AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ActivityRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        STRING_AGG(DISTINCT p.Title, ', ') AS PostTitles,
        STRING_AGG(DISTINCT a.Title, ', ') AS RelatedAnswers
    FROM 
        Tags t
    LEFT JOIN Posts p ON t.Id = p.Id
    LEFT JOIN Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    GROUP BY 
        t.TagName
)
SELECT 
    rp.PostID,
    rp.Title,
    u.DisplayName AS Author,
    u.Reputation,
    COALESCE(ueng.UpVotes, 0) AS TotalUpVotes,
    COALESCE(ueng.DownVotes, 0) AS TotalDownVotes,
    ts.PostCount AS TagPostCount,
    ts.PostTitles AS TagPostTitles,
    ra.UserId AS RecentActivityUser,
    ra.CreationDate AS RecentActivityDate,
    CASE 
        WHEN ra.PostHistoryTypeId IN (10, 11) THEN 'Closed or Reopened' 
        ELSE 'Other Activity'
    END AS ActivityType
FROM 
    RankedPosts rp
JOIN Users u ON u.Id = rp.PostID 
LEFT JOIN UserEngagement ueng ON ueng.UserID = u.Id
LEFT JOIN RecentActivity ra ON ra.PostId = rp.PostID
LEFT JOIN TagStatistics ts ON ts.TagName = ANY(STRING_TO_ARRAY(rp.Title, ' ')) 
WHERE 
    rp.CommentCount > 5 
    AND (u.Reputation BETWEEN 100 AND 1000 OR 
    (ueng.TotalVotes > 5 AND ts.PostCount > 1))
ORDER BY 
    rp.CreationDate DESC, 
    COALESCE(ueng.UpVotes, 0) DESC
LIMIT 50;
