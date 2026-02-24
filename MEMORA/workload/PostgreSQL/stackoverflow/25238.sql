
WITH TagStats AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount > 0 THEN p.ViewCount ELSE 0 END) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        t.Id, t.TagName
),
TopTags AS (
    SELECT 
        TagId,
        TagName,
        PostCount,
        TotalViews,
        AverageScore,
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC) AS TagRank
    FROM 
        TagStats
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived, 
        (SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
         SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END)) AS NetVotes
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        u.Id, u.DisplayName
),
Benchmark AS (
    SELECT 
        t.TagId,
        t.TagName,
        t.PostCount,
        t.TotalViews,
        t.AverageScore,
        u.UserId,
        u.DisplayName,
        u.UpVotesReceived,
        u.DownVotesReceived,
        u.NetVotes,
        b.BadgeCount,
        b.HighestBadgeClass
    FROM 
        TopTags t
    JOIN 
        PopularUsers u ON u.UpVotesReceived > 10  
    JOIN 
        UserBadges b ON b.UserId = u.UserId
    WHERE 
        t.TagRank <= 10  
)
SELECT 
    b.TagId,
    b.TagName,
    b.PostCount,
    b.TotalViews,
    b.AverageScore,
    b.UserId,
    b.DisplayName,
    b.UpVotesReceived,
    b.DownVotesReceived,
    b.NetVotes,
    b.BadgeCount,
    CASE 
        WHEN b.HighestBadgeClass = 1 THEN 'Gold'
        WHEN b.HighestBadgeClass = 2 THEN 'Silver'
        WHEN b.HighestBadgeClass = 3 THEN 'Bronze'
        ELSE 'None'
    END AS HighestBadge
FROM 
    Benchmark b
ORDER BY 
    b.TotalViews DESC, b.AverageScore DESC;
