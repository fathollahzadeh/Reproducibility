WITH PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.Score, 0)) AS TotalScore
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 5  
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalBadges DESC, TotalBounties DESC
    LIMIT 10
),
RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AcceptedAnswerId, 0) AS HasAcceptedAnswer,
        t.TagName
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    JOIN 
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostAnalytics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.HasAcceptedAnswer,
        STRING_AGG(DISTINCT pt.TagName, ', ') AS Tags
    FROM 
        RecentPosts rp
    JOIN 
        PopularTags pt ON pt.TagName = rp.TagName
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.CommentCount, rp.HasAcceptedAnswer
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.CommentCount,
    pa.HasAcceptedAnswer,
    pa.Tags,
    tu.DisplayName,
    tu.TotalBadges,
    tu.TotalBounties
FROM 
    PostAnalytics pa
JOIN 
    TopUsers tu ON pa.HasAcceptedAnswer = 1  
ORDER BY 
    pa.CreationDate DESC, 
    tu.TotalBadges DESC;