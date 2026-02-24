
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Tags,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC, p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.Tags,
        rp.Score,
        rp.CreationDate,
        rp.ViewCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5 
),
TagStats AS (
    SELECT 
        TagName,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews
    FROM (
        SELECT 
            UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS TagName,
            Score,
            ViewCount
        FROM 
            FilteredPosts
    ) AS unnested_tags
    GROUP BY 
        TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
FinalResults AS (
    SELECT 
        tg.TagName,
        tg.PostCount,
        tg.TotalScore,
        tg.TotalViews,
        ue.UserID,
        ue.DisplayName,
        ue.Upvotes,
        ue.Downvotes,
        ue.CommentCount,
        ue.BadgeCount
    FROM 
        TagStats tg
    JOIN 
        Users u ON u.Reputation > 1000 
    JOIN 
        UserEngagement ue ON ue.UserID = u.Id
    ORDER BY 
        tg.TotalScore DESC, tg.PostCount DESC
)
SELECT 
    fr.TagName,
    fr.PostCount,
    fr.TotalScore,
    fr.TotalViews,
    fr.UserID,
    fr.DisplayName,
    fr.Upvotes,
    fr.Downvotes,
    fr.CommentCount,
    fr.BadgeCount
FROM 
    FinalResults fr
LIMIT 100;
