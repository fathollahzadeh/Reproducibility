
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyEarned,
        RANK() OVER (ORDER BY COALESCE(SUM(v.BountyAmount), 0) DESC) as BountyRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
),
TopContributors AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        QuestionsCount, 
        AnswersCount, 
        TotalBountyEarned
    FROM 
        UserActivity
    WHERE 
        BountyRank <= 10
),
MostActivePostTags AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(p.Tags, '><')) AS TagName, 
        COUNT(*) AS PostCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    tc.DisplayName, 
    tc.TotalPosts, 
    tc.QuestionsCount, 
    tc.AnswersCount, 
    tc.TotalBountyEarned,
    mpt.TagName,
    mpt.PostCount
FROM 
    TopContributors tc
CROSS JOIN 
    MostActivePostTags mpt
ORDER BY 
    tc.TotalBountyEarned DESC, mpt.PostCount DESC;
