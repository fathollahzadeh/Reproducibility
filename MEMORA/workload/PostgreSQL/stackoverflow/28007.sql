WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        ARRAY_LENGTH(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><'), 1) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
PopularPosts AS (
    SELECT 
        ptc.PostId,
        ptc.Title,
        ptc.CreationDate,
        ptc.OwnerUserId,
        ptc.TagCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        PostTagCounts ptc
    LEFT JOIN 
        Votes v ON ptc.PostId = v.PostId AND v.VoteTypeId IN (2, 6) 
    WHERE 
        ptc.TagCount >= 3 
    GROUP BY 
        ptc.PostId, ptc.Title, ptc.CreationDate, ptc.OwnerUserId, ptc.TagCount
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore,
        COUNT(p.Id) AS QuestionCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        u.Id, u.DisplayName
    ORDER BY 
        TotalScore DESC
    LIMIT 5
)
SELECT 
    pp.Title,
    pp.CreationDate,
    u.DisplayName AS OwnerDisplayName,
    pp.TagCount,
    pp.VoteCount,
    tu.TotalViews,
    tu.TotalScore,
    tu.QuestionCount
FROM 
    PopularPosts pp
JOIN 
    Users u ON pp.OwnerUserId = u.Id
JOIN 
    TopUsers tu ON pp.OwnerUserId = tu.Id
ORDER BY 
    pp.VoteCount DESC, pp.TagCount DESC;