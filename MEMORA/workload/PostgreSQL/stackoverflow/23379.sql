
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        AVG(p.Score) AS AvgScore,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(p.ViewCount) AS MaxViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AvgScore,
        QuestionCount,
        AnswerCount,
        MaxViewCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC, AvgScore DESC) AS Rank
    FROM 
        UserPostStats
    WHERE 
        PostCount > 0
),
RecentPostHistory AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ph.CreationDate AS HistoryDate,
        p.ViewCount,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Other'
        END AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS RecentActivityRank
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
        OR ph.CreationDate IS NULL
),
FilteredPostLinks AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        lt.Name AS LinkType,
        COUNT(*) AS LinkCount
    FROM 
        PostLinks pl
    JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    WHERE 
        lt.Name IN ('Linked', 'Duplicate') 
    GROUP BY 
        pl.PostId, pl.RelatedPostId, lt.Name
),
PostRankings AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(pl.Id) AS RelatedLinks,
        RANK() OVER (ORDER BY COUNT(pl.Id) DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    tu.DisplayName,
    tu.PostCount,
    tu.AvgScore,
    pp.Title AS PostTitle,
    pp.PostRank,
    rph.HistoryDate,
    CASE 
        WHEN rph.HistoryType = 'Closed' THEN 'This post was closed recently.'
        ELSE 'This post has no recent closure activity.'
    END AS PostStatus,
    COALESCE(pl.LinkCount, 0) AS RelatedLinksCount,
    CASE 
        WHEN tu.PostCount = 0 THEN 'New User'
        WHEN tu.PostCount BETWEEN 1 AND 10 THEN 'Active User'
        WHEN tu.PostCount > 10 THEN 'Veteran User'
        ELSE 'Unknown'
    END AS UserStatus
FROM 
    TopUsers tu
JOIN 
    PostRankings pp ON tu.UserId = pp.Id 
LEFT JOIN 
    RecentPostHistory rph ON pp.Id = rph.PostId
LEFT JOIN 
    FilteredPostLinks pl ON pp.Id = pl.PostId
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
