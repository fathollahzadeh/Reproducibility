
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(EXTRACT(EPOCH FROM (p.LastActivityDate - p.CreationDate))) AS AvgPostLife
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        um.PostCount,
        um.TotalBounty,
        um.UpVotes,
        um.DownVotes,
        ROW_NUMBER() OVER (ORDER BY um.UpVotes DESC) AS URank,
        ROW_NUMBER() OVER (ORDER BY um.TotalBounty DESC) AS BRank
    FROM UserMetrics um
    WHERE um.PostCount > 0
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
    HAVING COUNT(DISTINCT p.Id) > 5
),
FinalMetrics AS (
    SELECT 
        tu.DisplayName,
        tu.PostCount,
        tu.TotalBounty,
        tu.UpVotes,
        tu.DownVotes,
        pt.TagName,
        pt.PostCount AS TagPostCount,
        pt.TotalViews
    FROM TopUsers tu
    JOIN PopularTags pt ON pt.PostCount = (
        SELECT MAX(PostCount) 
        FROM PopularTags 
        WHERE PostCount <= tu.PostCount
    )
)
SELECT
    DisplayName,
    PostCount,
    TotalBounty,
    UpVotes,
    DownVotes,
    COALESCE(TagName, 'No Tags') AS TagName,
    COALESCE(TagPostCount, 0) AS TagPostCount,
    COALESCE(TotalViews, 0) AS TotalViews
FROM FinalMetrics
ORDER BY UpVotes DESC, TotalBounty DESC
LIMIT 10;
