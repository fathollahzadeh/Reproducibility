
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
UserActivities AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(v.Id) AS VoteCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
TagStats AS (
    SELECT 
        t.Id AS TagId, 
        t.TagName, 
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.Id, t.TagName
),
ClosedPostDetails AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseReasonCount,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)

SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    rp.Title AS LatestPostTitle,
    rp.CreationDate AS LatestPostDate,
    rp.Score AS LatestPostScore,
    rp.ViewCount AS LatestPostViews,
    ua.VoteCount AS UserVoteCount,
    ua.UpVoteCount,
    ua.DownVoteCount,
    ts.TagName,
    ts.PostCount AS AssociatedPostCount,
    cp.CloseReasonCount,
    cp.CloseReasons
FROM 
    Users u
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.PostId
LEFT JOIN 
    UserActivities ua ON u.Id = ua.UserId
LEFT JOIN 
    TagStats ts ON ts.PostCount >= 10 
LEFT JOIN 
    ClosedPostDetails cp ON cp.PostId = rp.PostId
WHERE 
    rp.PostRank = 1
ORDER BY 
    u.Reputation DESC, 
    rp.CreationDate DESC
LIMIT 100;
