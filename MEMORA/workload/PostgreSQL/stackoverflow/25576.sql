
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(t.TagName) AS TagCount,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS QuestionCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        pt.TagCount,
        ups.TotalScore,
        ups.TotalViews,
        ups.TotalAnswers,
        RANK() OVER (ORDER BY ups.TotalScore DESC, pt.TagCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        PostTagCounts pt ON p.Id = pt.PostId
    JOIN 
        UserPostStats ups ON p.OwnerUserId = ups.UserId
    WHERE 
        p.PostTypeId = 1 
        AND pt.TagCount >= 2 
)
SELECT 
    rp.Rank,
    rp.Title,
    rp.TagCount,
    rp.TotalScore,
    rp.TotalViews,
    rp.TotalAnswers
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Rank;
