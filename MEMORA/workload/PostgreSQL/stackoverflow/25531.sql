
WITH TagSplits AS (
    SELECT 
        p.Id AS PostId,
        UNNEST(string_to_array(TRIM(BOTH '<>' FROM p.Tags), '><')) AS TagName
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
), 
TagCounts AS (
    SELECT 
        TagName,
        COUNT(DISTINCT PostId) AS PostCount
    FROM 
        TagSplits
    GROUP BY 
        TagName
), 
PopularTags AS (
    SELECT 
        TagName,
        PostCount
    FROM 
        TagCounts
    WHERE 
        PostCount > (
            SELECT 
                AVG(PostCount) 
            FROM 
                TagCounts
        )
),
UserVotes AS (
    SELECT 
        v.UserId, 
        COUNT(v.Id) AS VoteCount, 
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN vt.Name = 'Close' THEN 1 ELSE 0 END) AS CloseVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)

SELECT 
    ut.UserId,
    ut.DisplayName,
    ut.Reputation,
    ut.BadgeCount,
    SUM(COALESCE(u.VoteCount, 0)) AS TotalVotes,
    SUM(COALESCE(u.UpVotes, 0)) AS TotalUpVotes,
    SUM(COALESCE(u.DownVotes, 0)) AS TotalDownVotes,
    SUM(COALESCE(u.CloseVotes, 0)) AS TotalCloseVotes,
    STRING_AGG(DISTINCT pt.TagName, ', ') AS PopularTags
FROM 
    UserWithBadges ut
LEFT JOIN 
    UserVotes u ON ut.UserId = u.UserId
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (
        SELECT 
            UNNEST(string_to_array(TRIM(BOTH '<>' FROM p.Tags), '><')) 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = ut.UserId AND 
            p.PostTypeId = 1
    )
GROUP BY 
    ut.UserId, ut.DisplayName, ut.Reputation, ut.BadgeCount
ORDER BY 
    TotalVotes DESC, ut.Reputation DESC;
