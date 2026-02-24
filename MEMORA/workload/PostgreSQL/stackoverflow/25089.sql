
WITH TagFrequency AS (
    SELECT
        TRIM(t.TagName) AS TagName,
        COUNT(p.Id) AS PostCount
    FROM
        Tags t
    JOIN
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY
        TRIM(t.TagName)
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM
        TagFrequency
    WHERE
        PostCount > 10 
),
UserEngagement AS (
    SELECT
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentsCount,
        COUNT(b.Id) AS BadgesCount
    FROM
        Users u
    LEFT JOIN
        Votes v ON v.UserId = u.Id
    LEFT JOIN
        Comments c ON c.UserId = u.Id
    LEFT JOIN
        Badges b ON b.UserId = u.Id
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
ActiveUsers AS (
    SELECT
        ue.Id,
        ue.DisplayName,
        ue.Reputation,
        ue.UpVotes,
        ue.DownVotes,
        ue.CommentsCount,
        ue.BadgesCount,
        ROW_NUMBER() OVER (ORDER BY ue.Reputation DESC) AS UserRank
    FROM
        UserEngagement ue
    WHERE
        ue.CommentsCount > 5 
),
RecentPostEdits AS (
    SELECT
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        pt.Name AS PostTypeName,
        COUNT(ph.Id) AS EditCount
    FROM
        PostHistory ph
    JOIN
        Posts p ON p.Id = ph.PostId
    JOIN
        PostTypes pt ON pt.Id = p.PostTypeId
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY
        ph.PostId, ph.UserId, ph.CreationDate, pt.Name
)
SELECT
    tu.TagName,
    tu.PostCount AS TotalPosts,
    au.DisplayName AS UserName,
    au.Reputation AS UserReputation,
    au.UpVotes AS UserUpVotes,
    au.DownVotes AS UserDownVotes,
    au.CommentsCount AS UserCommentsCount,
    rp.PostId AS EditedPostId,
    rp.EditCount AS TotalEdits,
    rp.CreationDate AS LastEditDate,
    rp.PostTypeName
FROM
    TopTags tu
JOIN
    Posts p ON p.Tags LIKE CONCAT('%', tu.TagName, '%')
JOIN
    RecentPostEdits rp ON rp.PostId = p.Id
JOIN
    ActiveUsers au ON au.Id = rp.UserId
ORDER BY
    tu.PostCount DESC, au.Reputation DESC, rp.CreationDate DESC;
