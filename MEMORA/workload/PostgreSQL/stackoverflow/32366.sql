
WITH RecursiveTagCounts AS (
    SELECT
        tag.Id AS TagId,
        tag.TagName,
        COUNT(post.Id) AS PostCount
    FROM
        Tags tag
    LEFT JOIN
        Posts post ON post.Tags LIKE CONCAT('%', tag.TagName, '%') 
    GROUP BY
        tag.Id, tag.TagName
),
UserVoteStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistorySummary AS (
    SELECT
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeleteUndeleteCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    tt.TagName,
    rc.PostCount,
    u.Id AS UserId,
    u.DisplayName AS OwnerDisplayName,
    us.TotalVotes,
    us.UpVotes,
    us.DownVotes,
    COALESCE(phs.CloseReopenCount, 0) AS CloseReopenCount,
    COALESCE(phs.DeleteUndeleteCount, 0) AS DeleteUndeleteCount,
    phs.LastEditDate,
    CASE 
        WHEN (p.AcceptedAnswerId IS NOT NULL AND p.PostTypeId = 1)
            THEN 'Accepted Answer'
        WHEN (p.ViewCount > 1000)
            THEN 'Popular'
        ELSE 'Standard'
    END AS PostClassification
FROM 
    Posts p
LEFT JOIN 
    RecursiveTagCounts rc ON rc.PostCount > 0
LEFT JOIN 
    Users u ON u.Id = p.OwnerUserId
LEFT JOIN 
    UserVoteStats us ON us.UserId = u.Id
LEFT JOIN 
    PostHistorySummary phs ON phs.PostId = p.Id
LEFT JOIN 
    Tags tt ON tt.Id = p.Id
WHERE 
    p.LastActivityDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year' 
ORDER BY 
    p.CreationDate DESC, us.TotalVotes DESC
FETCH FIRST 100 ROWS ONLY;
