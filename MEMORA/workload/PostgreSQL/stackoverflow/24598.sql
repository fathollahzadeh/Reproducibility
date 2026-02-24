WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotesCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotesCount,
        COUNT(DISTINCT p.Id) AS PostsCount,
        MAX(u.CreationDate) AS LastActiveDate
    FROM 
        Users u 
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
),
BadgeSummary AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.AcceptedAnswerId
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostsWithTagCount
    FROM 
        Tags t
        LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.UpVotesCount,
    us.DownVotesCount,
    us.PostsCount,
    COALESCE(bs.TotalBadges, 0) AS TotalBadges,
    COALESCE(bs.BadgeNames, 'None') AS BadgeNames,
    pa.PostId,
    pa.Title AS PostTitle,
    pa.CommentCount,
    pa.UpVotes,
    pa.DownVotes,
    ts.TagName,
    ts.PostsWithTagCount
FROM 
    UserStats us
    LEFT JOIN BadgeSummary bs ON us.UserId = bs.UserId
    LEFT JOIN PostAnalytics pa ON pa.PostId = (
        SELECT 
            p2.Id 
        FROM Posts p2 
        WHERE p2.OwnerUserId = us.UserId 
        ORDER BY p2.CreationDate DESC 
        LIMIT 1
    )
    LEFT JOIN TagStats ts ON ts.PostsWithTagCount > 0
WHERE 
    (us.UpVotesCount - us.DownVotesCount) > 10
    AND EXISTS (
        SELECT 1 
        FROM Posts p 
        WHERE p.OwnerUserId = us.UserId
        HAVING COUNT(*) > 3
    ) 
ORDER BY 
    us.UpVotesCount DESC, us.DisplayName ASC
LIMIT 100;
